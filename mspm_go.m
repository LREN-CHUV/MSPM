function [varargout]=mspm_go(varargin)
% MSPM_GO MATLAB code for mspm_go.fig
%      MSPM_GO, by itself, creates a new MSPM_GO or raises the existing
%      singleton*.
%
%      H = MSPM_GO returns the handle to a new MSPM_GO or the handle to
%      the existing singleton*.
%
%      MSPM_GO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MSPM_GO.M with the given input arguments.
%
%      MSPM_GO('Property','Value',...) creates a new MSPM_GO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mspm_go_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mspm_go_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mspm_go

% Last Modified by GUIDE v2.5 30-Aug-2013 14:51:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mspm_go_OpeningFcn, ...
                   'gui_OutputFcn',  @mspm_go_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end
% --- Executes just before mspm_go is made visible.
function mspm_go_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mspm_go (see VARARGIN)

% Choose default command line output for mspm_go
handles.output = hObject;
load('MSPM.mat')
handles.SPM=SPM;

k=length(handles.SPM.yCon.xCon);
for i=1:k
    if k==0; break
    else
        initial_name=cellstr(get(handles.listbox1,'String'));
        new_name = [initial_name;{handles.SPM.yCon.xCon(i).name}];
        set(handles.listbox1,'String',new_name)
    end
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mspm_go wait for user response (see UIRESUME) 
set(handles.pushbutton2,'enable','off')
set(handles.pushbutton3,'enable','off')
uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = mspm_go_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1}=handles.z;
varargout{2}=handles.L;
varargout{3}=handles.SPM;
close
% Get default command line output from handles structure
end

function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('MSPM.mat')
[i,xCon]      = spm_conman(SPM.yCon,'T&F',Inf,'    Select contrasts L',' for inference',1);
SPM.yCon.xCon = xCon;
save('MSPM.mat','SPM');
initial_name=cellstr(get(handles.listbox1,'String'));
new_name = [initial_name;{SPM.yCon.xCon(i).name}];
set(handles.listbox1,'String',new_name)
guidata(hObject, handles);
end

% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zzz=get(hObject,'Value')-1;% indice of row selected in listbox2
if zzz==0; return
else
set(handles.pushbutton3,'enable','on')

load('MSPM.mat')

zz=find(SPM.M(handles.z,:)==1);
if size(zz,2)==1
    handles.L=zz;
else
    handles.L=zz(zzz);
end
guidata(hObject, handles);
% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
end
end

% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows. 
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listbox2,'String','Listbox')
z=get(hObject,'Value')-1;  % indice of row selected in listbox1
if z==0; return
else
set(handles.pushbutton2,'enable','on')
load('MSPM.mat')
handles.z=z;
zz=find(SPM.M(z,:)==1);
handles.zz=zz;
for i=zz;
    if isempty(i)==1; break
    else
        initial_name=cellstr(get(handles.listbox2,'String'));
        new_name = [initial_name;{SPM.xCon(i).name}];
        set(handles.listbox2,'String',new_name)
    end
end
guidata(hObject, handles);
end
end
% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listbox2,'String','Listbox')
load('MSPM.mat')
[j,xCon]    = spm_conman(SPM,'T&F',Inf,'    Select contrasts c',' for inference',1);
SPM.xCon = xCon;
handles.j=j;
SPM.M(handles.z,handles.j)=1;
save('MSPM.mat','SPM');

z=handles.z;
zz=find(SPM.M(z,:)==1);

for i=zz;
    if isempty(i)==1; break
    else
        initial_name=cellstr(get(handles.listbox2,'String'));
        new_name = [initial_name;{SPM.xCon(i).name}];
        set(handles.listbox2,'String',new_name)
    end
end

handles.SPM=SPM;
guidata(hObject, handles);
end




% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);
end



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
delete(hObject);
end

% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
end
